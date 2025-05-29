import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/models/plant_model.dart';
import '../../../app/constants/app_constants.dart';

class EditPlantScreen extends StatefulWidget {
  final bool isEditing;
  final Plant? plant;

  const EditPlantScreen({
    super.key,
    required this.isEditing,
    this.plant,
  });

  @override
  EditPlantScreenState createState() => EditPlantScreenState();
}

class EditPlantScreenState extends State<EditPlantScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scientificNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _selectedCategory = AppConstants.plantCategories.first;
  final _growthDurationController = TextEditingController();
  String _selectedDifficulty = 'Sedang';
  final _wateringFrequencyController = TextEditingController();
  final _sunlightRequirementController = TextEditingController();
  final _soilTypeController = TextEditingController();
  final _harvestTimeController = TextEditingController();
  final _benefitsController = TextEditingController();

  // Planting steps and care instructions
  final List<Map<String, dynamic>> _plantingSteps = [];
  final List<Map<String, dynamic>> _careInstructions = [];

  bool _isLoading = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Theme colors
  static const Color primaryColor = Color(0xFF2D5A27);
  static const Color primaryLight = Color(0xFF4CAF50);
  static const Color primarySurface = Color(0xFFF1F8E9);
  static const Color surfaceColor = Color(0xFFFAFAFA);
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color dividerColor = Color(0xFFE0E0E0);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeController.forward();
    _slideController.forward();
  }

  void _initializeData() {
    if (widget.isEditing && widget.plant != null) {
      final plant = widget.plant!;
      _nameController.text = plant.name;
      _scientificNameController.text = plant.scientificName;
      _descriptionController.text = plant.description;
      _imageUrlController.text = plant.imageUrl;
      _selectedCategory = plant.category;
      _growthDurationController.text = plant.growthDuration.toString();
      _selectedDifficulty = plant.difficulty;
      _wateringFrequencyController.text = plant.wateringFrequency;
      _sunlightRequirementController.text = plant.sunlightRequirement;
      _soilTypeController.text = plant.soilType;
      _harvestTimeController.text = plant.harvestTime;
      _benefitsController.text = plant.benefits;
      _plantingSteps.addAll(plant.plantingSteps);
      _careInstructions.addAll(plant.careInstructions);
    } else {
      _addEmptyPlantingStep();
      _addEmptyCareInstruction();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _scientificNameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    _growthDurationController.dispose();
    _wateringFrequencyController.dispose();
    _sunlightRequirementController.dispose();
    _soilTypeController.dispose();
    _harvestTimeController.dispose();
    _benefitsController.dispose();
    super.dispose();
  }

  void _addEmptyPlantingStep() {
    setState(() {
      _plantingSteps.add({
        'stepNumber': _plantingSteps.length + 1,
        'title': '',
        'description': '',
      });
    });
  }

  void _removePlantingStep(int index) {
    setState(() {
      _plantingSteps.removeAt(index);
      for (int i = 0; i < _plantingSteps.length; i++) {
        _plantingSteps[i]['stepNumber'] = i + 1;
      }
    });
  }

  void _addEmptyCareInstruction() {
    setState(() {
      _careInstructions.add({
        'title': '',
        'description': '',
      });
    });
  }

  void _removeCareInstruction(int index) {
    setState(() {
      _careInstructions.removeAt(index);
    });
  }

  Future<void> _savePlant() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final firestore = FirebaseFirestore.instance;
        final now = DateTime.now();
        final plantData = {
          'name': _nameController.text,
          'scientificName': _scientificNameController.text,
          'description': _descriptionController.text,
          'imageUrl': _imageUrlController.text,
          'category': _selectedCategory,
          'growthDuration': int.tryParse(_growthDurationController.text) ?? 0,
          'difficulty': _selectedDifficulty,
          'wateringFrequency': _wateringFrequencyController.text,
          'sunlightRequirement': _sunlightRequirementController.text,
          'soilType': _soilTypeController.text,
          'harvestTime': _harvestTimeController.text,
          'benefits': _benefitsController.text,
          'plantingSteps': _plantingSteps,
          'careInstructions': _careInstructions,
          'updatedAt': now,
        };

        if (widget.isEditing && widget.plant != null) {
          await firestore.collection('plants').doc(widget.plant!.id).update(plantData);
        } else {
          plantData['createdAt'] = now;
          await firestore.collection('plants').add(plantData);
        }

        if (mounted) {
          _showSuccessMessage();
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) _showErrorMessage('Error: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(widget.isEditing
                ? 'Tanaman berhasil diperbarui'
                : 'Tanaman berhasil ditambahkan'),
          ],
        ),
        backgroundColor: primaryLight,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEditing ? 'Edit Tanaman' : 'Tambah Tanaman';
    return Scaffold(
      backgroundColor: surfaceColor,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(title),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  SlideTransition(
                    position: _slideAnimation,
                    child: _isLoading ? _buildLoadingState() : _buildForm(),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // AppBar
  Widget _buildAppBar(String title) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: cardColor,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primarySurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primarySurface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.isEditing ? Icons.edit : Icons.add_circle_outline,
                color: primaryColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            color: cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Loading state
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: primaryLight,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.isEditing ? 'Menyimpan perubahan...' : 'Menambahkan tanaman...',
            style: const TextStyle(
              fontSize: 16,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Main form
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 24),
          _buildBasicInfoSection(),
          const SizedBox(height: 24),
          _buildGrowingInfoSection(),
          const SizedBox(height: 24),
          _buildPlantingStepsSection(),
          const SizedBox(height: 24),
          _buildCareInstructionsSection(),
          const SizedBox(height: 32),
          _buildSaveButton(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // Header card
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primarySurface,
            primarySurface.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isEditing ? 'Edit Tanaman 🌱' : 'Tambah Tanaman Baru 🌿',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isEditing
                      ? 'Perbarui informasi tanaman dengan data terbaru'
                      : 'Tambahkan tanaman baru ke dalam database hortikultura',
                  style: const TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: cardColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.eco_outlined,
              color: primaryColor,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  // Basic info section
  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Informasi Dasar',
      icon: Icons.info_outline,
      children: [
        _buildTextField(
          controller: _nameController,
          label: 'Nama Tanaman',
          hint: 'Masukkan nama tanaman',
          icon: Icons.local_florist,
          validator: (value) =>
              value == null || value.isEmpty ? 'Nama tanaman tidak boleh kosong' : null,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _scientificNameController,
          label: 'Nama Ilmiah',
          hint: 'Masukkan nama ilmiah (Latin)',
          icon: Icons.science_outlined,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _descriptionController,
          label: 'Deskripsi',
          hint: 'Masukkan deskripsi tanaman',
          icon: Icons.description_outlined,
          maxLines: 3,
          validator: (value) =>
              value == null || value.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _imageUrlController,
          label: 'URL Gambar',
          hint: 'https://example.com/image.jpg',
          icon: Icons.image_outlined,
          validator: (value) =>
              value == null || value.isEmpty ? 'URL Gambar tidak boleh kosong' : null,
        ),
        const SizedBox(height: 20),
        _buildCategoryDropdown(),
      ],
    );
  }

  // Growing info section
  Widget _buildGrowingInfoSection() {
    return _buildSection(
      title: 'Informasi Pertumbuhan',
      icon: Icons.trending_up,
      children: [
        _buildTextField(
          controller: _growthDurationController,
          label: 'Durasi Pertumbuhan (hari)',
          hint: 'Masukkan durasi dalam hari',
          icon: Icons.schedule_outlined,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 20),
        _buildDifficultyDropdown(),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _wateringFrequencyController,
          label: 'Frekuensi Penyiraman',
          hint: 'Misal: Setiap 2-3 hari',
          icon: Icons.water_drop_outlined,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _sunlightRequirementController,
          label: 'Kebutuhan Sinar Matahari',
          hint: 'Misal: Sinar matahari penuh',
          icon: Icons.wb_sunny_outlined,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _soilTypeController,
          label: 'Jenis Tanah',
          hint: 'Misal: Tanah gembur kaya humus',
          icon: Icons.grass_outlined,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _harvestTimeController,
          label: 'Waktu Panen',
          hint: 'Misal: 75-90 hari setelah tanam',
          icon: Icons.access_time_outlined,
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _benefitsController,
          label: 'Manfaat',
          hint: 'Masukkan manfaat tanaman',
          icon: Icons.favorite_outline,
          maxLines: 3,
        ),
      ],
    );
  }

  // Planting steps section
  Widget _buildPlantingStepsSection() {
    return _buildSection(
      title: 'Langkah-langkah Penanaman',
      icon: Icons.format_list_numbered,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              decoration: BoxDecoration(
                color: primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: primaryColor, size: 20),
                onPressed: _addEmptyPlantingStep,
                tooltip: 'Tambah Langkah',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_plantingSteps.isEmpty)
          _buildEmptyState(
            icon: Icons.list_alt_outlined,
            title: 'Belum ada langkah penanaman',
            subtitle: 'Klik tombol + untuk menambahkan langkah',
          )
        else
          ..._plantingSteps.asMap().entries.map((entry) {
            return _buildPlantingStepField(entry.key, entry.value);
          }).toList(),
      ],
    );
  }

  // Care instructions section
  Widget _buildCareInstructionsSection() {
    return _buildSection(
      title: 'Instruksi Perawatan',
      icon: Icons.handyman_outlined,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              decoration: BoxDecoration(
                color: primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: primaryColor, size: 20),
                onPressed: _addEmptyCareInstruction,
                tooltip: 'Tambah Instruksi',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_careInstructions.isEmpty)
          _buildEmptyState(
            icon: Icons.spa_outlined,
            title: 'Belum ada instruksi perawatan',
            subtitle: 'Klik tombol + untuk menambahkan instruksi',
          )
        else
          ..._careInstructions.asMap().entries.map((entry) {
            return _buildCareInstructionField(entry.key, entry.value);
          }).toList(),
      ],
    );
  }

  // Generic section builder
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: primaryColor),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }

  // Generic text field builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryLight, width: 2),
            ),
            filled: true,
            fillColor: surfaceColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  // Category dropdown
  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.category_outlined, size: 18, color: primaryColor),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Kategori',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryLight, width: 2),
            ),
            filled: true,
            fillColor: surfaceColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: AppConstants.plantCategories.map((category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value!;
            });
          },
        ),
      ],
    );
  }

  // Difficulty dropdown
  Widget _buildDifficultyDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.trending_up_outlined, size: 18, color: primaryColor),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Tingkat Kesulitan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedDifficulty,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: primaryLight, width: 2),
            ),
            filled: true,
            fillColor: surfaceColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: ['Mudah', 'Sedang', 'Sulit'].map((difficulty) {
            return DropdownMenuItem<String>(
              value: difficulty,
              child: Text(difficulty),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedDifficulty = value!;
            });
          },
        ),
      ],
    );
  }

  // Planting step field
  Widget _buildPlantingStepField(int index, Map<String, dynamic> step) {
    final titleController = TextEditingController(text: step['title']);
    final descriptionController = TextEditingController(text: step['description']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: primaryLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Langkah ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 18),
                  onPressed: () => _removePlantingStep(index),
                  tooltip: 'Hapus Langkah',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: 'Judul Langkah',
              hintText: 'Misal: Persiapan Benih',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: dividerColor.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryLight, width: 2),
              ),
              filled: true,
              fillColor: cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _plantingSteps[index]['title'] = value;
              });
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: descriptionController,
            decoration: InputDecoration(
              labelText: 'Deskripsi Langkah',
              hintText: 'Masukkan deskripsi langkah',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: dividerColor.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryLight, width: 2),
              ),
              filled: true,
              fillColor: cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: 2,
            onChanged: (value) {
              setState(() {
                _plantingSteps[index]['description'] = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // Care instruction field
  Widget _buildCareInstructionField(int index, Map<String, dynamic> instruction) {
    final titleController = TextEditingController(text: instruction['title']);
    final descriptionController = TextEditingController(text: instruction['description']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.handyman_outlined,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Instruksi ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 18),
                  onPressed: () => _removeCareInstruction(index),
                  tooltip: 'Hapus Instruksi',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: 'Judul Instruksi',
              hintText: 'Misal: Penyiraman',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: dividerColor.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryLight, width: 2),
              ),
              filled: true,
              fillColor: cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _careInstructions[index]['title'] = value;
              });
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: descriptionController,
            decoration: InputDecoration(
              labelText: 'Deskripsi Instruksi',
              hintText: 'Masukkan deskripsi instruksi',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: dividerColor.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: primaryLight, width: 2),
              ),
              filled: true,
              fillColor: cardColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: 2,
            onChanged: (value) {
              setState(() {
                _careInstructions[index]['description'] = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // Save button
  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryLight,
            primaryColor,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryLight.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _savePlant,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.isEditing ? Icons.save : Icons.add_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              widget.isEditing ? 'Simpan Perubahan' : 'Tambah Tanaman',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty state widget
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: textSecondary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: textSecondary.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}